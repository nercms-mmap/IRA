clear

sim = importdata('similarity.mat');
% ranker * query * gallery

query_label = importdata('queryID.mat');
gallery_label = importdata('galleryID.mat');
% Used to stimulate interaction

iteration = 10; % Number of interaction rounds
K = 3; % Interaction per round
error_rate = 0.02; % Interaction error rate

rankernum = size(sim,1);
querynum = size(sim,2);
gallerynum = size(sim,3);
[~,ranklist] = sort(-sim,3);
[~,rank] = sort(ranklist,3);

averageRank = sum(sim, 1);
averageRank = reshape(averageRank,querynum,gallerynum);
[~,pseudoRanklist] = sort(-averageRank,2);
[~,pseudoRank] = sort(pseudoRanklist,2);

feedtrue_G = zeros(querynum,gallerynum);
feeded_G = zeros(querynum,gallerynum);

weight = ones(querynum,rankernum);

%get origin rank
origin_sim = zeros(querynum,gallerynum);
for i=1:querynum
    for j = 1:rankernum
        origin_sim(i,:) = origin_sim(i,:) + reshape(sim(j,i,:) * weight(i,j),1,gallerynum);
    end
end
[~,origin_ranklist] = sort(-origin_sim,2);
[~,origin_rank] = sort(origin_ranklist,2);
total_ranklist = origin_ranklist;



for i = 1:iteration
    new_weight = zeros(querynum,rankernum);
    for q = 1:querynum
        Qlabel = query_label(q);
        sed = 0;
        now_num = 1;
        while sed<K
            if feeded_G(q,total_ranklist(q,now_num)) == 0
                sed = sed +1;
                RT(sed) = total_ranklist(q,now_num);
                feeded_G(q,total_ranklist(q,now_num)) = 1;
            end
            now_num = now_num + 1;
        end
        RT_label = gallery_label(RT);
        scored_G = find(RT_label == Qlabel);
        for j = 1:K
            if ismember(j,scored_G)
                if rand(1) > error_rate
                    feedtrue_G(q,RT(j)) = 10;
                else
                    feedtrue_G(q,RT(j)) = -10;
                end
            else
                if rand(1) > error_rate
                    feedtrue_G(q,RT(j)) = -10;
                else
                    feedtrue_G(q,RT(j)) = 10;
                end
            end
        end
        scored_G = find(feedtrue_G(q,:)==10);
        for j = 1:rankernum
            ranker_RT = ranklist(j,q,:);
            A = [];
            for k = 1:size(scored_G,2)
                x = find(ranker_RT==scored_G(k));
                score = ceil(x/K);
                new_weight(q,j) = new_weight(q,j) + 1/score;
            end
        end
        total_weight = max(new_weight(q,:));
        new_weight(q,:) = new_weight(q,:) ./ total_weight;
    end
    weight = weight .* 0.1 + new_weight .* 0.9;
    for j = 1:querynum
        weight(j,:) = weight(j,:) ./ max(weight(j,:));
    end
    new_sim = zeros(querynum,gallerynum);
    for j=1:querynum
        for k = 1:rankernum
            new_sim(j,:) = new_sim(j,:) + reshape(sim(k,j,:) * weight(j,k),1,gallerynum);
        end
    end
    new_sim = new_sim + feedtrue_G;
    [~,total_ranklist] = sort(-new_sim,2);
    [~,total_rank] = sort(total_ranklist,2);
end

save('Rank_based_result.mat','total_rank');
